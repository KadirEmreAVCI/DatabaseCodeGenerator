#include "ColumnItemModel.h"

ColumnItemModel::ColumnItemModel(const QString& sType, bool blIsEnabled, bool blIsPrimaryKey, bool blIsRelationSource, const Position& rPosition, const QString& sName, QObject *parent)
    : Model(rPosition, sName, parent), m_sType(sType), m_blIsEnabled(blIsEnabled), m_blIsPrimaryKey(blIsPrimaryKey), m_blIsRelationSource(blIsRelationSource)
{
}

QString ColumnItemModel::GetType() const
{
    return m_sType;
}
bool ColumnItemModel::GetIsEnabled() const
{
    return m_blIsEnabled;
}
bool ColumnItemModel::GetIsPrimaryKey() const
{
    return m_blIsPrimaryKey;
}
bool ColumnItemModel::GetIsRelationSource() const
{
    return m_blIsRelationSource;
}
void ColumnItemModel::SetType(const QString &type)
{
    if (m_sType != type) 
    {
        m_sType = type;
        emit typeChanged();
    }
}
void ColumnItemModel::SetIsEnabled(bool blIsEnabled)
{
    if (m_blIsEnabled != blIsEnabled) 
    {
        m_blIsEnabled = blIsEnabled;
        emit isEnabledChanged();
    }
}
void ColumnItemModel::SetIsPrimaryKey(bool blIsPrimaryKey)
{
    if (m_blIsPrimaryKey != blIsPrimaryKey) 
    {
        m_blIsPrimaryKey = blIsPrimaryKey;
        emit isPrimaryKeyChanged();
    }
}
void ColumnItemModel::SetIsRelationSource(bool blIsRelationSource)
{
    if (m_blIsRelationSource != blIsRelationSource) 
    {
        m_blIsRelationSource = blIsRelationSource;
        emit isRelationSourceChanged();
    }
}