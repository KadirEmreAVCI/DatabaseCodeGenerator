#include "TableController.h"
#include "TableModel.h"

// Standard Library
#include <algorithm>
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
bool TableController::IsNameDuplicated(int iChangedTableID, const QString& sNewName)const
{
    return std::any_of(m_mapTable.cbegin(), m_mapTable.cend(), [=](const auto& prTable){
        const int iID = prTable.first;
        const TableModel* const pTableModel = prTable.second;
        return (iChangedTableID != iID) && (sNewName == pTableModel->GetName());
    });
}
void TableController::onTableNameChangeRequested(int iTableID, const QString& sNewName)
{
    if(auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end())
    {
        if(TableModel* const pTableModel = iterTable->second; pTableModel != nullptr)
        {
            const QString sOldName{pTableModel->GetName()};
            if(!IsNameDuplicated(iTableID, sNewName))
            {
                pTableModel->SetName(sNewName);
            }
            else
            {
                const QString sWarningMessage = tr("A table with name '%1' already exists. You cannot rename '%2' to this name.").arg(sNewName, sOldName);
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