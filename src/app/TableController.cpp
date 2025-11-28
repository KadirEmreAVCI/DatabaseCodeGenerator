#include "TableController.h"
#include "TableModel.h"

// Standard Library
#include <QDebug>

TableController::TableController(QObject *parent)
    : QObject{parent}
{
}
void TableController::AddTable(TableModel* pTable)
{
    if(nullptr != pTable)
    {
        m_mapTable.insert(std::make_pair(pTable->GetID(), pTable));
    }
    else
    {
        qDebug() << "Error: TableModel pointer is null.";
    }
}
void TableController::onTableNameChangeRequested(int iTableID, const QString& sNewName)
{
    if(auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end())
    {
        if(TableModel* const pTableModel = iterTable->second; pTableModel != nullptr)
        {
            pTableModel->SetName(sNewName);
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
QList<QObject*> TableController::GetTables() const
{
    QList<QObject*> lsTable;
    lsTable.reserve(static_cast<int>(m_mapTable.size()));
    for (auto [iID, pTable] : m_mapTable) 
    {
        if (pTable) 
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