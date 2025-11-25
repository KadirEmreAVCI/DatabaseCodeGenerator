#include "ColumnModel.h"

ColumnModel::ColumnModel(const QString& sType, bool blIsEnabled, bool blIsPrimaryKey, bool blIsRelationSource, const Position& rPosition, const QString& sName, QObject *parent)
    : Model(rPosition, sName, parent), m_sType(sType), m_blIsEnabled(blIsEnabled), m_blIsPrimaryKey(blIsPrimaryKey), m_blIsRelationSource(blIsRelationSource)
{
}

QString ColumnModel::GetType() const
{
    return m_sType;
}
bool ColumnModel::GetIsEnabled() const
{
    return m_blIsEnabled;
}
bool ColumnModel::GetIsPrimaryKey() const
{
    return m_blIsPrimaryKey;
}
bool ColumnModel::GetIsRelationSource() const
{
    return m_blIsRelationSource;
}
void ColumnModel::SetType(const QString &type)
{
    if (m_sType != type) 
    {
        m_sType = type;
        emit typeChanged();
    }
}
void ColumnModel::SetIsEnabled(bool blIsEnabled)
{
    if (m_blIsEnabled != blIsEnabled) 
    {
        m_blIsEnabled = blIsEnabled;
        emit isEnabledChanged();
    }
}
void ColumnModel::SetIsPrimaryKey(bool blIsPrimaryKey)
{
    if (m_blIsPrimaryKey != blIsPrimaryKey) 
    {
        m_blIsPrimaryKey = blIsPrimaryKey;
        emit isPrimaryKeyChanged();
    }
}
void ColumnModel::SetIsRelationSource(bool blIsRelationSource)
{
    if (m_blIsRelationSource != blIsRelationSource) 
    {
        m_blIsRelationSource = blIsRelationSource;
        emit isRelationSourceChanged();
    }
}