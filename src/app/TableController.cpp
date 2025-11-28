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
    m_mapTable.insert(std::make_pair(pTable->GetID(), pTable));
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