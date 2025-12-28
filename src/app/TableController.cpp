#include "TableController.h"
#include "TableModel.h"
#include "ColumnListModel.h"
#include "RelationModel.h"

// Standard Library
#include <algorithm>
#include <iostream>
#include <QDebug>

TableController& TableController::GetInstance()
{
    static TableController instance;
    return instance;
}
TableController::TableController(QObject *parent)
    : QObject{parent}
{
}
void TableController::AddTable(std::shared_ptr<TableModel> spTable)
{
    if(nullptr != spTable)
    {
        spTable->SetID(m_iNextTableID++);
        m_mapspTable.emplace(spTable->GetID(), spTable);
        emit tablesChanged();
    }
    else
    {
        qDebug() << "Error: TableModel pointer is null.";
    }
}
void TableController::AddRelation(int iSourceTableID, int iDestinationTableID)
{
    if(auto spSourceTable = GetTable(iSourceTableID); spSourceTable != nullptr)
    {
        if(auto spDestinationTable = GetTable(iDestinationTableID); spDestinationTable != nullptr)
        {
            if(spSourceTable->AddRelation(spSourceTable, spDestinationTable))
            {
                RelationsChanged();
            }
        }
        else
        {
            qDebug() << "Error: Destination TableModel pointer is null.";
        }
    }
    else
    {
        qDebug() << "Error: Source TableModel pointer is null.";
    }
}
void TableController::onTableNameChangeRequested(int iTableID, const QString& sNewName)
{
    if(auto iterTable = m_mapspTable.find(iTableID); iterTable != m_mapspTable.end())
    {
        if(const auto spTableModel = iterTable->second; spTableModel != nullptr)
        {
            const QString sOldName{spTableModel->GetName()};
            const QString sNormalizedNewName{NormalizeTableName(sNewName)};
            if(!IsNameDuplicated(iTableID, sNormalizedNewName))
            {
                spTableModel->SetName(sNormalizedNewName);
            }
            else
            {
                const QString sWarningMessage = tr("A table with name '%1' already exists. You cannot rename '%2' to this name.").arg(sNormalizedNewName, sOldName);
                emit tableNameChangeRejected(iTableID, sWarningMessage);
            }
        }
        else
        {
            qDebug() << "Error: TableModel pointer is null.";
        }
    }
    else
    {
        qDebug() << "Error: Table ID not found.";
    }
}
void TableController::onTablePositionChangeRequested(int iTableID, const QPointF& rPointF)
{
    if (auto iterTable = m_mapspTable.find(iTableID); iterTable != m_mapspTable.end()) 
    {
        const auto spTable = iterTable->second;
        if (spTable != nullptr) 
        {
            spTable->SetPoint(rPointF);
        }
    }
}
void TableController::onCreateNewTable(const QPointF& rPointF)
{
    int iTableIDOffset = 0;
    QString sTempNewName = "";
    do
    {
        sTempNewName = QString("Table %1").arg(m_iNextTableID + iTableIDOffset++);
    }
    while(IsNameDuplicated(m_iNextTableID, sTempNewName));
    AddTable(std::make_shared<TableModel>(this, sTempNewName, rPointF));
}
QRectF TableController::GetBoundingRect() const
{
    QRectF rUnitedRect{};
    bool blFirstRect = true;

    for(const auto &[iID, spTable] : m_mapspTable) 
    {
        if(!spTable)
        { 
            continue;
        }
        QRectF rNextRect(spTable->GetPointF().x(), spTable->GetPointF().y(), spTable->GetWidth(), spTable->GetHeight()); 
        if(blFirstRect) 
        {
            rUnitedRect = rNextRect;
            blFirstRect = false;
        } 
        else 
        {
            rUnitedRect = rUnitedRect.united(rNextRect);
        }
    }
    return rUnitedRect;
}
std::map<int, std::shared_ptr<RelationModel>> TableController::GetRelations()const
{
    std::map<int, std::shared_ptr<RelationModel>> mapRelations;
    for (const auto& [iID, spTable] : m_mapspTable) 
    {
        if (spTable != nullptr) 
        {
            const auto tableRelations = spTable->GetRelations();
            mapRelations.insert(tableRelations.begin(), tableRelations.end());
        } 
        else 
        {
            qDebug() << "Warning: null TableModel for id" << iID;
        }
    }
    return mapRelations;
}
bool TableController::IsNameDuplicated(int iChangedTableID, const QString& sNewName)const
{
    return std::any_of(m_mapspTable.cbegin(), m_mapspTable.cend(), [iChangedTableID, sNewName](const auto& pairTable){
        const auto& [iID, spTableModel] = pairTable;
        return (iChangedTableID != iID) && (sNewName == spTableModel->GetName());
    });
}
QString TableController::NormalizeTableName(const QString& sName) const
{
    if (sName.isEmpty())
    {
        return sName;
    }
    QString sNormalized = sName.toLower();          
    sNormalized[0] = sNormalized[0].toUpper();       
    return sNormalized;
}
bool TableController::IsRelationExists(int iSourceTableID, int iDestinationTableID)const
{
    auto mapRelations = GetRelations();
    return std::any_of(mapRelations.cbegin(), mapRelations.cend(), [iSourceTableID, iDestinationTableID](const auto& spRelation){
        if(spRelation.second != nullptr)
        {
            return (spRelation.second->GetSourceTableID() == iSourceTableID) && (spRelation.second->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
void TableController::RelationsChanged()
{
    m_mapspRelations = GetRelations();
    emit relationsChanged();
}
QList<QObject*> TableController::GetTableList() const
{
    QList<QObject*> lsTable;
    lsTable.reserve(static_cast<int>(m_mapspTable.size()));
    for (const auto& [iID, spTable] : m_mapspTable) 
    {
        if (spTable != nullptr) 
        {
            lsTable.append(spTable.get());
        } 
        else 
        {
            qDebug() << "Warning: null TableModel for id" << iID;
        }
    }
    return lsTable;
}
QList<QObject*> TableController::GetRelationList()const
{
    QList<QObject*> lsRelations;
    lsRelations.reserve(static_cast<int>(m_mapspRelations.size()));
    for (const auto& [iID, spRelation] : m_mapspRelations) 
    {
        if (spRelation != nullptr) 
        {
            lsRelations.append(spRelation.get());
        } 
        else 
        {
            qDebug() << "Warning: null Relation TableModel for id" << iID;
        }
    }
    return lsRelations;
}
std::shared_ptr<TableModel> TableController::GetTable(int iTableID)const
{
    std::shared_ptr<TableModel> spTableModel = nullptr;
    if (auto iterTable = m_mapspTable.find(iTableID); iterTable != m_mapspTable.end()) 
    {
        spTableModel = iterTable->second;
    }
    return spTableModel;
}
void TableController::onTableDeleteRequested(int iDeletedTableID)
{
    // Delete relations if deleted table is not source table.
    std::shared_ptr<TableModel> spDeletedtable = nullptr;
    for(auto [iTableID, spTable] : m_mapspTable)
    {
        if(spTable != nullptr)
        {
            if(iTableID != iDeletedTableID)
            {
                spTable->TableDeleteRequested(iDeletedTableID);
            }
            else
            {
                spDeletedtable = spTable;
            }
        }
    }
    if(spDeletedtable != nullptr)
    {
        m_mapspTable.erase(iDeletedTableID);
        emit tablesChanged();
    }
}
void TableController::onRelationshipDeleteRequested(int iRelationID)
{
    if(auto iterRelation = m_mapspRelations.find(iRelationID); iterRelation != m_mapspRelations.end() && iterRelation->second != nullptr)
    {
        if(auto iterSourceTable = m_mapspTable.find(iterRelation->second->GetSourceTableID()); iterSourceTable != m_mapspTable.end() && iterSourceTable->second != nullptr)
        {
            if(iterSourceTable->second->RemoveRelation(iRelationID))
            {
                RelationsChanged();
            }
        }
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iRelationID << "to delete.";
    }
}
void TableController::onRelationshipChangeRequested(int iRelationID, const QString& sRelationship)
{
    auto mapRelations = GetRelations();
    if(auto iterChangedRelation = mapRelations.find(iRelationID); iterChangedRelation != mapRelations.end() && iterChangedRelation->second != nullptr)
    {
        iterChangedRelation->second->SetRelationship(sRelationship);
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iRelationID << "to change relationship.";
    }
}
void TableController::onNewRelationEstablished(int iSourceTableID, int iDestinationTableID)
{
    if(!IsRelationExists(iSourceTableID, iDestinationTableID))
    {
        AddRelation(iSourceTableID, iDestinationTableID);
    }
}