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
void TableController::AddTable(std::shared_ptr<TableModel> spTable)
{
    if(nullptr != spTable)
    {
        spTable->SetID(m_iNextTableID++);
        m_mapspTable.insert(std::make_pair(spTable->GetID(), std::shared_ptr<TableModel>(spTable)));
        emit tablesChanged();
    }
    else
    {
        qDebug() << "Error: TableModel pointer is null.";
    }
}
void TableController::TableDeleted(int iTableID)
{
    if (auto iterTable = m_mapspTable.find(iTableID); iterTable != m_mapspTable.end()) 
    {
        if (iterTable->second != nullptr) 
        {
            m_mapspTable.erase(iterTable);
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
bool TableController::RelationshipDeleted(int iSourceTableID, int iDestinationTableID)
{
    if(auto iterSourceTable = m_mapspTable.find(iSourceTableID); iterSourceTable != m_mapspTable.end() && iterSourceTable->second != nullptr)
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
QString TableController::FindRelationColumnName(int iDestinationTableID) const
{
    QString sRelationColumnName{}; 
    if(auto iterDestinationTable = m_mapspTable.find(iDestinationTableID); iterDestinationTable != m_mapspTable.end() && iterDestinationTable->second != nullptr)
    {
        sRelationColumnName = iterDestinationTable->second->GetName() + "ID";
    }
    else
    {
        qDebug() << "Error: Destination Table ID not found.";
    }
    return sRelationColumnName;
}
QList<QObject*> TableController::GetTables() const
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
std::shared_ptr<const TableModel> TableController::GetTable(int iTableID)const
{
    std::shared_ptr<const TableModel> spTableModel = nullptr;
    if (auto iterTable = m_mapspTable.find(iTableID); iterTable != m_mapspTable.end()) 
    {
        spTableModel = iterTable->second;
    }
    return spTableModel;
}
void TableController::NewRelationEstablished(int iSourceTableID, int iDestinationTableID)
{
    if(auto iterSourceTable = m_mapspTable.find(iSourceTableID); iterSourceTable != m_mapspTable.end() && iterSourceTable->second != nullptr)
    {
        iterSourceTable->second->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>(FindRelationColumnName(iDestinationTableID), "INT", false, false, true));
    }
    else
    {
        qDebug() << "Error: Source Table ID not found.";
    }
}