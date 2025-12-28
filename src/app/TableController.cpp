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
void TableController::onChangeTableNameRequested(int iRenamedTableID, const QString& sNewName)
{
    if(auto spRenamedTable = GetTable(iRenamedTableID); spRenamedTable != nullptr)
    {
        const QString sOldName{spRenamedTable->GetName()};
        const QString sNormalizedNewName{NormalizeTableName(sNewName)};
        if(!IsNameDuplicated(iRenamedTableID, sNormalizedNewName))
        {
            spRenamedTable->SetName(sNormalizedNewName);
        }
        else
        {
            const QString sWarningMessage = tr("A table with name '%1' already exists. You cannot rename '%2' to this name.").arg(sNormalizedNewName, sOldName);
            emit tableNameChangeRejected(iRenamedTableID, sWarningMessage);
        }
    }
    else
    {
        qDebug() << "Error: Table ID not found.";
    }
}
void TableController::onTablePositionChangeRequested(int iRelocatedTableID, const QPointF& rPointF)
{
    if (auto spRelocatedTable = GetTable(iRelocatedTableID); spRelocatedTable != nullptr) 
    {
        spRelocatedTable->SetPoint(rPointF);
    } 
    else 
    {
        qDebug() << "Error: Table ID not found.";
    }
}
void TableController::onCreateNewTableRequested(const QPointF& rPointF)
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
std::map<int, std::shared_ptr<RelationModel>> TableController::GatherRelationsFromTables()const
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
    return std::any_of(m_mapspRelations.cbegin(), m_mapspRelations.cend(), [iSourceTableID, iDestinationTableID](const auto& spRelation){
        if(spRelation.second != nullptr)
        {
            return (spRelation.second->GetSourceTableID() == iSourceTableID) && (spRelation.second->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
void TableController::RelationsChanged()
{
    m_mapspRelations = GatherRelationsFromTables();
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
std::shared_ptr<RelationModel> TableController::GetRelation(int iRelationID)const
{
    std::shared_ptr<RelationModel> spRelationModel = nullptr;
    if (auto iterRelation = m_mapspRelations.find(iRelationID); iterRelation != m_mapspRelations.end()) 
    {
        spRelationModel = iterRelation->second;
    }
    return spRelationModel;
}
void TableController::onDeleteTableRequested(int iDeletedTableID)
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
void TableController::onDeleteRelationRequested(int iDeletedRelationID)
{
    if(auto spDeletedRelation = GetRelation(iDeletedRelationID); spDeletedRelation != nullptr)
    {
        if(auto spSourceTable = GetTable(spDeletedRelation->GetSourceTableID()); spSourceTable != nullptr)
        {
            if(spSourceTable->RemoveRelation(iDeletedRelationID))
            {
                RelationsChanged();
            }
        }
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iDeletedRelationID << "to delete.";
    }
}
void TableController::onChangeRelationshipRequested(int iChangedRelationID, const QString& sRelationship)
{
    if(auto spChangedRelation = GetRelation(iChangedRelationID); spChangedRelation != nullptr)
    {
        spChangedRelation->SetRelationship(sRelationship);
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iChangedRelationID << "to change relationship.";
    }
}
void TableController::onCreateNewRelationRequested(int iSourceTableID, int iDestinationTableID)
{
    if(!IsRelationExists(iSourceTableID, iDestinationTableID))
    {
        AddRelation(iSourceTableID, iDestinationTableID);
    }
}