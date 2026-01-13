#include "Model.h"

Model::Model(int iID, QObject *parent)
    : m_iID{iID}, QObject{parent} 
{
}
int Model::GetID() const
{
    return m_iID;
}
void Model::SetID(int iID)
{
    if(m_iID != iID)
    {
        m_iID = iID;
        emit idChanged();
    }
}