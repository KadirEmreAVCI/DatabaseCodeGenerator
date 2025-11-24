#include "ColumnItemModel.h"

ColumnItemModel::ColumnItemModel(const QString& sType, const Position& rPosition, const QString& sName, QObject *parent)
    : Model(rPosition, sName, parent), m_sType(sType)
{
}

QString ColumnItemModel::GetType() const
{
    return m_sType;
}

void ColumnItemModel::SetType(const QString &type)
{
    if (m_sType != type) 
    {
        m_sType = type;
        emit typeChanged();
    }
}