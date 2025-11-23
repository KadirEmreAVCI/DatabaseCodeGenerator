#include "TableModel.h"

TableModel::TableModel(const QString& sName, const Position& rPosition, QObject *parent) : m_sName{sName}, Model{rPosition, parent}
{
}
TableModel::~TableModel()
{
}
QString TableModel::GetName() const
{
    return m_sName;
}
void TableModel::SetName(const QString &sName)
{
    if(m_sName != sName)
    {
        m_sName = sName;
        emit nameChanged();
    }
}