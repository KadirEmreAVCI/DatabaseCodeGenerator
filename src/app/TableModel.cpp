#include "TableModel.h"

TableModel::TableModel(const QString& sName, const Position& rPosition, QObject *parent) 
    : Model{rPosition, sName, parent}, m_pColumnListModel{new ColumnListModel(this)}
{
}
ColumnListModel* TableModel::GetColumnListModel() const
{
    return m_pColumnListModel;
}
void TableModel::SetColumnListModel(ColumnListModel* pColumnListModel)
{
    m_pColumnListModel = pColumnListModel;
}
