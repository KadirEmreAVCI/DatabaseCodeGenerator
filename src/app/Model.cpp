#include "Model.h"

Model::Model(int iID, QObject *parent)
    : m_iID{iID}, QObject{parent}
{
}
int Model::GetID() const
{
    return m_iID;
}