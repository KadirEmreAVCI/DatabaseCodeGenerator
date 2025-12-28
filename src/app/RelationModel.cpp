#include "RelationModel.h"
#include "ColumnListModel.h"
#include <iostream>

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(std::shared_ptr<const TableModel> spDestinationTable, std::shared_ptr<const TableModel> spSourceTable, const QString& sRelationship, QObject* pParent)
    : m_sRelationship{sRelationship}, Model{pParent}
{
    if(spDestinationTable != nullptr)
    {
        SetDestinationTable(spDestinationTable);
    }
    if(spSourceTable != nullptr)
    {
        SetSourceTable(spSourceTable);
    }
}
int RelationModel::GetID() const
{
    return m_iID;
}
std::shared_ptr<const TableModel> RelationModel::GetDestinationTable()const
{
    return m_spDestinationTable;
}
std::shared_ptr<const TableModel> RelationModel::GetSourceTable()const
{
    return m_spSourceTable;
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
void RelationModel::SetDestinationTable(std::shared_ptr<const TableModel> spDestinationTable)
{
    if(m_spDestinationTable != spDestinationTable)
    {
        m_spDestinationTable = spDestinationTable;
        m_iDestinationTableID = m_spDestinationTable->GetID();
        emit destinationTableIDChanged();
    }
} 
void RelationModel::SetSourceTable(std::shared_ptr<const TableModel> spSourceTable)
{
    if(m_spSourceTable != spSourceTable)
    {
        m_spSourceTable = spSourceTable;
        m_iSourceTableID = m_spSourceTable->GetID();
        UpdateSourceRowIdx();
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
void RelationModel::UpdateSourceRowIdx()
{
    if(m_spSourceTable != nullptr)
    {
        m_iSourceRowIdx = -1;
        const QString sSourceColumnName = m_spDestinationTable->GetName() + "ID";
        const ColumnListModel* const pColumnListModel{m_spSourceTable->GetColumnListModel()};
        for(unsigned idx = 0; idx < pColumnListModel->rowCount(); ++idx)
        {
            if(pColumnListModel->GetColumn(idx)["name"] == sSourceColumnName)
            {
                m_iSourceRowIdx = idx;
                break;
            }
        }
    }
    else
    {
        std::cerr << "RelationModel::CalculateSourceRowIdx m_pSourceTableModel is nullptr!\n";
    }
}