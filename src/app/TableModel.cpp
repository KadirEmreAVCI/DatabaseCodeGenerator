#include "TableModel.h"

TableModel::TableModel(const QString& sName, QObject *parent) : QObject(parent)
{
    SetName(sName);
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