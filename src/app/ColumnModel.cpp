#include "ColumnModel.h"

ColumnModel::ColumnModel(int iID, const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique, bool blIsForeignKey, int iRelationID, QObject *parent)
    : m_sName{sName}, 
    m_sType(sType), 
    m_blIsEnabled(!(blIsPrimaryKey || blIsForeignKey)), 
    m_blIsPrimaryKey(blIsPrimaryKey), 
    m_blIsForeignKey(blIsForeignKey), 
    m_iRelationID{iRelationID},
    Model(iID, parent)
{}   
QString ColumnModel::GetName() const
{
    return m_sName;
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
bool ColumnModel::GetIsForeignKey() const
{
    return m_blIsForeignKey;
}
int ColumnModel::GetRelationID()const
{
    return m_iRelationID;
}
void ColumnModel::SetName(const QString &name)
{
    if(m_sName != name)
    {
        m_sName = name;
        emit nameChanged();
    }
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
void ColumnModel::SetIsForeignKey(bool blIsForeignKey)
{
    if (m_blIsForeignKey != blIsForeignKey) 
    {
        m_blIsForeignKey = blIsForeignKey;
        emit isForeignKeyChanged();
    }
}