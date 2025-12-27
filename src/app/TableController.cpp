#include "TableController.h"
#include "TableModel.h"
#include "RelationController.h"

// Standard Library
#include <algorithm>
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
void TableController::AddTable(TableModel* pTable)
{
    if(nullptr != pTable)
    {
        pTable->SetID(m_iNextTableID++);
        m_mapTable.insert(std::make_pair(pTable->GetID(), pTable));
        emit tablesChanged();
    }
    else
    {
        qDebug() << "Error: TableModel pointer is null.";
    }
}
bool TableController::RelationshipDeleted(int iSourceTableID, int iDestinationTableID)
{
    if(auto iterSourceTable = m_mapTable.find(iSourceTableID); iterSourceTable != m_mapTable.end() && iterSourceTable->second != nullptr)
    {
        ColumnListModel* const pColumnListModel = iterSourceTable->second->GetColumnListModel();
        const QString sRelationColumnName = FindRelationColumnName(iDestinationTableID);
        for(int idx = 0; idx < pColumnListModel->rowCount(); ++idx)
        {
            if(pColumnListModel->GetColumn(idx)["name"] == sRelationColumnName)
            {
                return pColumnListModel->RemoveColumn(idx);
            }
        }
    }
    else
    {
        qDebug() << "Error: Source Table ID not found.";
    }
    return false;
}
void TableController::onTableNameChangeRequested(int iTableID, const QString& sNewName)
{
    if(auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end())
    {
        if(TableModel* const pTableModel = iterTable->second; pTableModel != nullptr)
        {
            const QString sOldName{pTableModel->GetName()};
            const QString sNormalizedNewName{NormalizeTableName(sNewName)};
            if(!IsNameDuplicated(iTableID, sNormalizedNewName))
            {
                pTableModel->SetName(sNormalizedNewName);
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
    if (auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end()) 
    {
        const auto pTable = iterTable->second;
        if (pTable != nullptr) 
        {
            pTable->SetPoint(rPointF);
        }
    }
}
void TableController::onTableDeleteRequested(int iTableID)
{
    if (auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end()) 
    {
        DeleteRelationBasedColumnsFromDestinationTables(iTableID);
        const auto pTable = iterTable->second;
        if (pTable != nullptr) 
        {
            delete pTable;
            m_mapTable.erase(iterTable);
            RelationController::GetInstance().TableDeleted(iTableID);  
            emit tablesChanged();
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
void TableController::onCreateNewTable(const QPointF& rPointF)
{
    int iTableIDOffset = 0;
    QString sTempNewName = "";
    do
    {
        sTempNewName = QString("Table %1").arg(m_iNextTableID + iTableIDOffset++);
    }
    while(IsNameDuplicated(m_iNextTableID, sTempNewName));
    AddTable(new TableModel(this, sTempNewName, rPointF));
}
QRectF TableController::GetBoundingRect() const
{
    QRectF rUnitedRect{};
    bool blFirstRect = true;

    for(const auto &[iID, pTable] : m_mapTable) 
    {
        if(!pTable)
        { 
            continue;
        }
        QRectF rNextRect(pTable->GetPointF().x(), pTable->GetPointF().y(), pTable->GetWidth(), pTable->GetHeight()); 
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
bool TableController::IsNameDuplicated(int iChangedTableID, const QString& sNewName)const
{
    return std::any_of(m_mapTable.cbegin(), m_mapTable.cend(), [=](const auto& prTable){
        const int iID = prTable.first;
        const TableModel* const pTableModel = prTable.second;
        return (iChangedTableID != iID) && (sNewName == pTableModel->GetName());
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
QString TableController::FindRelationColumnName(int iDestinationTableID) const
{
    QString sRelationColumnName{}; 
    if(auto iterDestinationTable = m_mapTable.find(iDestinationTableID); iterDestinationTable != m_mapTable.end() && iterDestinationTable->second != nullptr)
    {
        sRelationColumnName = iterDestinationTable->second->GetName() + "ID";
    }
    else
    {
        qDebug() << "Error: Destination Table ID not found.";
    }
    return sRelationColumnName;
}
void TableController::DeleteRelationBasedColumnsFromDestinationTables(int iDeletedTableID)
{
    for(auto [iID, pTable] : m_mapTable)
    {
        if(pTable != nullptr && iID != iDeletedTableID)
        {
            ColumnListModel* const pColumnListModel = pTable->GetColumnListModel();
            const QString sRelationBasedColumnName = FindRelationColumnName(iDeletedTableID);
            for(int idx = 0; idx < pColumnListModel->rowCount(); ++idx)
            {
                if(pColumnListModel->GetColumn(idx)["name"] == sRelationBasedColumnName && pColumnListModel->GetColumn(idx)["isRelationSource"].toBool())
                {
                    pColumnListModel->RemoveColumn(idx);
                    break;
                }
            }
        }
    }
}
QList<QObject*> TableController::GetTables() const
{
    QList<QObject*> lsTable;
    lsTable.reserve(static_cast<int>(m_mapTable.size()));
    for (auto [iID, pTable] : m_mapTable) 
    {
        if (pTable != nullptr) 
        {
            lsTable.append(pTable);
        } 
        else 
        {
            qDebug() << "Warning: null TableModel for id" << iID;
        }
    }
    return lsTable;
}
const TableModel* TableController::GetTable(int iTableID)const
{
    const TableModel* pTableModel = nullptr;
    if (auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end()) 
    {
        pTableModel = iterTable->second;
    }
    return pTableModel;
}
void TableController::NewRelationEstablished(int iSourceTableID, int iDestinationTableID)
{
    if(auto iterSourceTable = m_mapTable.find(iSourceTableID); iterSourceTable != m_mapTable.end() && iterSourceTable->second != nullptr)
    {
        iterSourceTable->second->GetColumnListModel()->AddColumn(new ColumnModel(FindRelationColumnName(iDestinationTableID), "INT", false, false, true));
    }
    else
    {
        qDebug() << "Error: Source Table ID not found.";
    }
}