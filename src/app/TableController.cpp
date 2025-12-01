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
void TableController::onTablePositionChangeRequested(int iTableID, const QPoint& rPoint)
{
    if (auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end()) 
    {
        const auto pTable = iterTable->second;
        if (pTable != nullptr) 
        {
            pTable->SetPoint(rPoint);
        }
    }
}
void TableController::onTableDeleteRequested(int iTableID)
{
    if (auto iterTable = m_mapTable.find(iTableID); iterTable != m_mapTable.end()) 
    {
        const auto pTable = iterTable->second;
        if (pTable != nullptr) 
        {
            delete pTable;
            m_mapTable.erase(iterTable);
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
void TableController::onCreateNewTable(const QPoint& rPoint)
{
    int iTableIDOffset = 0;
    QString sTempNewName = "";
    do{
        sTempNewName = QString("Table %1").arg(m_iNextTableID + iTableIDOffset++);
    }while(IsNameDuplicated(m_iNextTableID, sTempNewName));
    AddTable(new TableModel(sTempNewName, rPoint, this));
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