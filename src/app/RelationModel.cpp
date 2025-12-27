#include "RelationModel.h"
#include <iostream>

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(const TableModel* pDestinationTableModel, const TableModel* pSourceTableModel, const QString& sRelationship, QObject* pParent)
    : m_sRelationship{sRelationship}, Model{pParent}
{
    if(pDestinationTableModel != nullptr)
    {
        SetDestinationTableModel(pDestinationTableModel);
    }
    if(pSourceTableModel != nullptr)
    {
        SetSourceTableModel(pSourceTableModel);
    }
}
int RelationModel::GetID() const
{
    return m_iID;
}
const TableModel* RelationModel::GetDestinationTableModel()const
{
    return m_pDestinationTableModel;
}
const TableModel* RelationModel::GetSourceTableModel()const
{
    return m_pSourceTableModel;
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
void RelationModel::SetDestinationTableModel(const TableModel* pDestinationTableModel)
{
    if(m_pDestinationTableModel != pDestinationTableModel)
    {
        m_pDestinationTableModel = pDestinationTableModel;
        m_iDestinationTableID = m_pDestinationTableModel->GetID();
        emit destinationTableIDChanged();
    }
} 
void RelationModel::SetSourceTableModel(const TableModel* pSourceTableModel)
{
    if(m_pSourceTableModel != pSourceTableModel)
    {
        m_pSourceTableModel = pSourceTableModel;
        m_iSourceTableID = m_pSourceTableModel->GetID();
        CalculateSourceRowIdx();
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
void RelationModel::CalculateSourceRowIdx()
{
    if(m_pSourceTableModel != nullptr)
    {
        m_iSourceRowIdx = -1;
        const QString sSourceColumnName = m_pDestinationTableModel->GetName() + "ID";
        const ColumnListModel* const pColumnListModel{m_pSourceTableModel->GetColumnListModel()};
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