#include "TableModel.h"

TableModel::TableModel(const QString& sName, const Position& rPosition, QObject *parent) 
    : m_sName{sName}, m_rPosition{rPosition}, m_pColumnListModel{new ColumnListModel(this)}, Model(parent)
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
int TableModel::GetX() const
{
    return m_rPosition.x;
}
int TableModel::GetY() const
{
    return m_rPosition.y;
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
void TableModel::SetPosition(int x, int y)
{
    if(m_rPosition.x != x || m_rPosition.y != y)
    {
        m_rPosition.x = x;
        m_rPosition.y = y;
        emit positionChanged();
    }
}