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
        pTable->SetID(m_iNextTableID++);
        m_mapTable.insert(std::make_pair(pTable->GetID(), pTable));
        emit tablesChanged();
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
void TableController::onCreateNewTable()
{
    const auto pTableModel = new TableModel(QString("Table %1").arg(m_iNextTableID), Position{0, 0}, this);
    AddTable(pTableModel);
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