#include "TableModel.h"

TableModel::TableModel(const QString& sName, const Position& rPosition, QObject *parent) 
    : Model{rPosition, parent}, m_sName{sName}, m_pColumnListModel{new ColumnListModel(this)}
{
}
QString TableModel::GetName() const
{
    return m_sName;
}
ColumnListModel* TableModel::GetColumnListModel() const
{
    return m_pColumnListModel;
}
void TableModel::SetColumnListModel(ColumnListModel* pColumnListModel)
{
    m_pColumnListModel = pColumnListModel;
}
void TableModel::SetName(const QString &name)
{
    if(m_sName != name)
    {
        m_sName = name;
        emit nameChanged();
    }
}