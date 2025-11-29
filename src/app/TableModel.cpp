#include "TableModel.h"

TableModel::TableModel(const QString& sName, const QPoint& rPoint, QObject *parent) 
    : m_sName{sName}, m_rPoint{rPoint}, m_pColumnListModel{new ColumnListModel(this)}, Model(parent)
{
}
int TableModel::GetID() const
{
    return m_iID;
}
QString TableModel::GetName() const
{
    return m_sName;
}
QPoint TableModel::GetPoint()const
{
    return m_rPoint;
}
ColumnListModel* TableModel::GetColumnListModel() const
{
    return m_pColumnListModel;
}
void TableModel::SetColumnListModel(ColumnListModel* pColumnListModel)
{
    m_pColumnListModel = pColumnListModel;
}
void TableModel::SetID(int iID)
{
    if(m_iID != iID)
    {
        m_iID = iID;
        emit idChanged();
    }
}
void TableModel::SetName(const QString &name)
{
    if(m_sName != name)
    {
        m_sName = name;
        emit nameChanged();
    }
}
void TableModel::SetPoint(const QPoint& rPoint)
{
    if(m_rPoint != rPoint)
    {
        m_rPoint = rPoint;
        emit pointChanged();
    }
}