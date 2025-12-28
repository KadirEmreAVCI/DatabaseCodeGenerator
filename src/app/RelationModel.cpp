#include "RelationModel.h"
#include "TableModel.h"
#include <iostream>

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(int iID, std::weak_ptr<const TableModel> wpDestinationTable, std::weak_ptr<const TableModel> wpSourceTable, const QString& sRelationship, QObject* pParent)
    : m_iID{iID}, m_sRelationship{sRelationship}, Model{pParent}
{
    if (!wpDestinationTable.expired()) 
    {
        SetDestinationTable(wpDestinationTable);
    }
    if (!wpSourceTable.expired()) 
    {
        SetSourceTable(wpSourceTable);
    }
}
int RelationModel::GetID() const
{
    return m_iID;
}
std::weak_ptr<const TableModel> RelationModel::GetDestinationTable()const
{
    return m_wpDestinationTable;
}
std::weak_ptr<const TableModel> RelationModel::GetSourceTable()const
{
    return m_wpSourceTable;
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
int RelationModel::GetSourceTableID()const
{
    return m_iSourceTableID;
}
QString RelationModel::GetRelationship()const
{
    return m_sRelationship;
}
void RelationModel::SetID(int iID)
{
    if(m_iID != iID)
    {
        m_iID = iID;
        emit idChanged();
    }
}
void RelationModel::SetDestinationTable(std::weak_ptr<const TableModel> wpDestinationTable)
{
    if(m_wpDestinationTable.lock() != wpDestinationTable.lock())
    {
        m_wpDestinationTable = wpDestinationTable;
        m_iDestinationTableID = m_wpDestinationTable.lock()->GetID();
        emit destinationTableIDChanged();
    }
} 
void RelationModel::SetSourceTable(std::weak_ptr<const TableModel> wpSourceTable)
{
    if(m_wpSourceTable.lock() != wpSourceTable.lock())
    {
        m_wpSourceTable = wpSourceTable;
        m_iSourceTableID = m_wpSourceTable.lock()->GetID();
        Update();
        emit sourceRowIdxChanged();
        emit sourceTableIDChanged();
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
void RelationModel::Update()
{
    UpdateSourceRowIdx();
}
void RelationModel::UpdateSourceRowIdx()
{
    m_iSourceRowIdx = -1;
    if(auto spSourceTable = m_wpSourceTable.lock(); spSourceTable != nullptr)
    {
        const QString sSourceColumnName = m_wpDestinationTable.lock()->GetName() + "ID";
        m_iSourceRowIdx = spSourceTable->GetColumnIdxByName(sSourceColumnName);
    }
    else
    {
        std::cerr << "RelationModel::UpdateSourceRowIdx m_wpSourceTable is nullptr!\n";
    }
}