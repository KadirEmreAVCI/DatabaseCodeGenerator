#include "RelationModel.h"

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(int iDestinationTableID, int iSourceRowIdx, QString sRelationship, QObject* pParent)
    : m_iDestinationTableID{iDestinationTableID}, m_iSourceRowIdx{iSourceRowIdx}, m_sRelationship{sRelationship}, Model{pParent}
{

}

int RelationModel::GetDestinationRowIdx()const
{
    return ms_iDestinationRowIdx;
}
int RelationModel::GetDestinationTableID()const
{
    return m_iDestinationTableID;
}
int RelationModel::GetSourceRowIdx()const
{
    return m_iSourceRowIdx;
}
QString RelationModel::GetRelationship()const
{
    return m_sRelationship;
}
void RelationModel::SetDestinationTableID(int iDestinationTableID)
{
    if(m_iDestinationTableID != iDestinationTableID)
    {
        m_iDestinationTableID = iDestinationTableID;
        emit destinationTableIDChanged();
    }
}
void RelationModel::SetSourceRowIdx(int iSourceRowIdx)
{
    if(m_iSourceRowIdx != iSourceRowIdx)
    {
        m_iSourceRowIdx = iSourceRowIdx;
        emit sourceRowIdxChanged();
    }
}
void RelationModel::SetRelationship(const QString& sRelationship)
{
    if(m_sRelationship != sRelationship)
    {
        m_sRelationship = sRelationship;
        emit relationshipChanged();
    }
}