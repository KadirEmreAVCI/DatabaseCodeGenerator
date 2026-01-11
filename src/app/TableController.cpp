#include "TableController.h"
#include "TableModel.h"
#include "RelationModel.h"
#include "ColumnModel.h"

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
void TableController::AddTable(const QPointF& rPointF, const QString& sTableName)
{
    m_vecupTables.push_back(std::make_unique<TableModel>(m_iNextTableID++, sTableName, rPointF));
    emit tablesChanged();
}
void TableController::AddRelation(int iSourceTableID, int iDestinationTableID)
{
    if(auto pSourceTable = GetTable(iSourceTableID); pSourceTable != nullptr)
    {
        if(auto pDestinationTable = GetTable(iDestinationTableID); pDestinationTable != nullptr)
        {
            auto upRelation = std::make_unique<RelationModel>(ms_iNextRelationID++, pDestinationTable, pSourceTable, "1..*");
            pSourceTable->Attach(upRelation.get(), RelationRole::eOutgoing);
            pDestinationTable->Attach(upRelation.get(), RelationRole::eIncoming);
            m_vecupRelations.push_back(std::move(upRelation));
            emit relationsChanged();
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
    if(auto pRenamedTable = GetTable(iRenamedTableID); pRenamedTable != nullptr)
    {
        const QString sOldName{pRenamedTable->GetName()};
        const QString sNormalizedNewName{NormalizeTableName(sNewName)};
        if(!IsNameDuplicated(iRenamedTableID, sNormalizedNewName))
        {
            pRenamedTable->SetName(sNormalizedNewName);
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
    if (auto pRelocatedTable = GetTable(iRelocatedTableID); pRelocatedTable != nullptr) 
    {
        pRelocatedTable->SetPoint(rPointF);
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
    AddTable(rPointF, sTempNewName);
}
void TableController::onCreateNewColumnRequested(int iTableID, const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique)
{
    if(auto pTable = GetTable(iTableID); pTable != nullptr)
    {
        pTable->AddColumn(std::make_unique<ColumnModel>(sName, sType, blNotNull, blIsPrimaryKey, blAutoIncrement, blUnique, false));
    }
    else
    {
        qDebug() << "Error: Table ID not found.";
    }
}
QRectF TableController::GetBoundingRect() const
{
    QRectF rUnitedRect{};
    bool blFirstRect = true;

    for(const auto& upTable : m_vecupTables) 
    {
        if(!upTable)
        { 
            continue;
        }
        QRectF rNextRect(upTable->GetPointF().x(), upTable->GetPointF().y(), upTable->GetWidth(), upTable->GetHeight()); 
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
TableModel* TableController::GetTable(int iTableID)
{
    auto iterupTable = std::find_if(m_vecupTables.begin(), m_vecupTables.end(), [iTableID](const auto& upTable){
        return upTable->GetID() == iTableID;
    });
    return (iterupTable != m_vecupTables.end()) ? iterupTable->get() : nullptr;
}
RelationModel* TableController::GetRelation(int iRelationID)
{
    auto iterupRelation = std::find_if(m_vecupRelations.begin(), m_vecupRelations.end(), [iRelationID](const auto& upRelation){
        return upRelation->GetID() == iRelationID;
    });
    return (iterupRelation != m_vecupRelations.end()) ? iterupRelation->get() : nullptr;
}
bool TableController::IsNameDuplicated(int iChangedTableID, const QString& sNewName)const
{
    return std::any_of(m_vecupTables.cbegin(), m_vecupTables.cend(), [iChangedTableID, sNewName](const auto& upTable){
        return (upTable->GetID() != iChangedTableID) && (upTable->GetName() == sNewName);
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
    return std::any_of(m_vecupRelations.cbegin(), m_vecupRelations.cend(), [iSourceTableID, iDestinationTableID](const auto& upRelation){
        if(upRelation != nullptr)
        {
            return (upRelation->GetSourceTableID() == iSourceTableID) && (upRelation->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
std::vector<int> TableController::GetRelationIDsIfTableInvolved(int iTableID)
{   
    std::vector<int> vecRelationIDsTableInvolved;
    vecRelationIDsTableInvolved.reserve(m_vecupRelations.size());
    if(const TableModel* const pTable = GetTable(iTableID); pTable != nullptr)
    {
        for (const auto& upReletion : m_vecupRelations)
        {
            if (!upReletion) 
            {
                continue;
            }
            else
            {  
                if (upReletion->GetSourceTable() == pTable || upReletion->GetDestinationTable() == pTable)
                {
                    vecRelationIDsTableInvolved.push_back(upReletion->GetID());
                }
            }
        }
    }
    return vecRelationIDsTableInvolved;
}
QList<QObject*> TableController::GetTableList() const
{
    QList<QObject*> lsTable;
    lsTable.reserve(static_cast<int>(m_vecupTables.size()));
    for (const auto& upTable : m_vecupTables) 
    {
        if (upTable != nullptr) 
        {
            lsTable.append(upTable.get());
        } 
    }
    return lsTable;
}
QList<QObject*> TableController::GetRelationList()const
{
    QList<QObject*> lsRelations;
    lsRelations.reserve(static_cast<int>(m_vecupRelations.size()));
    for (const auto& upRelation : m_vecupRelations) 
    {
        if (upRelation != nullptr) 
        {
            lsRelations.append(upRelation.get());
        } 
    }
    return lsRelations;
}
void TableController::onDeleteTableRequested(int iDeletedTableID)
{
    if(auto pDeletedTable = GetTable(iDeletedTableID); pDeletedTable != nullptr)
    {
        auto vecRelationIDsTableInvolved = GetRelationIDsIfTableInvolved(iDeletedTableID);
        for(int iDeletedRelation : vecRelationIDsTableInvolved)
        {
            onDeleteRelationRequested(iDeletedRelation);
        }
        std::erase_if(m_vecupTables, [&](const std::unique_ptr<TableModel>& upTable) {
            return upTable && upTable->GetID() == iDeletedTableID;
        });
        emit tablesChanged();
    }
    else
    {
        qDebug() << "Error: Table ID not found.";
    }
}
void TableController::onDeleteRelationRequested(int iDeletedRelationID)
{
    if(auto pDeletedRelation = GetRelation(iDeletedRelationID); pDeletedRelation != nullptr)
    {
        if(auto pDestinationTable = pDeletedRelation->GetDestinationTable(); pDestinationTable != nullptr)
        {
            pDestinationTable->Detach(pDeletedRelation, RelationRole::eIncoming);
        }
        if(auto pSourceTable = pDeletedRelation->GetSourceTable(); pSourceTable != nullptr)
        {
            pSourceTable->Detach(pDeletedRelation, RelationRole::eOutgoing);
        }
        std::erase_if(m_vecupRelations, [&](const std::unique_ptr<RelationModel>& r){
                return r->GetID() == iDeletedRelationID;
            });
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: Relation ID not found.";
    }
}
void TableController::onChangeRelationshipRequested(int iChangedRelationID, const QString& sRelationship)
{
    if(auto pChangedRelation = GetRelation(iChangedRelationID); pChangedRelation != nullptr)
    {
        pChangedRelation->SetRelationship(sRelationship);
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