#include "RelationModel.h"
#include "TableModel.h"
#include <iostream>
#include <QDebug>

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(int iID, TableModel* pDestinationTable, TableModel* pSourceTable, const QString& sRelationship, QObject* pParent)
    : m_iID{iID}, m_sRelationship{sRelationship}, m_pDestinationTable{pDestinationTable}, m_pSourceTable{pSourceTable}, Model{pParent}
{}
int RelationModel::GetID() const
{
    return m_iID;
}
TableModel* RelationModel::GetDestinationTable()const
{
    return m_pDestinationTable;
}
TableModel* RelationModel::GetSourceTable()const
{
    return m_pSourceTable;
}
int RelationModel::GetDestinationRowIdx()const
{
    return ms_iDestinationRowIdx;
}
int RelationModel::GetDestinationTableID()const
{
    return m_pDestinationTable->GetID();
}
int RelationModel::GetSourceRowIdx()const
{
    return m_pSourceTable->GetRelationBasedColumnIdx(m_iID);
}
int RelationModel::GetSourceTableID()const
{
    return m_pSourceTable->GetID();
}
QString RelationModel::GetRelationship()const
{
    return m_sRelationship;
}
QString RelationModel::GetRelationBasedColumnName()const
{
    return m_pDestinationTable->GetName() + "ID";
}
void RelationModel::DestinationTableRenamed()const
{
    if(m_pSourceTable && m_pDestinationTable)
    {
        m_pSourceTable->RenameRelationBasedColumn(m_iID, GetRelationBasedColumnName());
    }
}
void RelationModel::SetID(int iID)
{
    m_iID = iID;  
    emit idChanged();
}
void RelationModel::SetDestinationTable(TableModel* pDestinationTable)
{
    if(pDestinationTable != nullptr)
    {
        m_pDestinationTable = pDestinationTable;
        emit destinationTableIDChanged();
    }
} 
void RelationModel::SetSourceTable(TableModel* pSourceTable)
{
    if(m_pSourceTable != pSourceTable)
    {
        m_pSourceTable = pSourceTable;
        emit sourceTableIDChanged();
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