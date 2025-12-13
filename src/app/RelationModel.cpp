#include "RelationModel.h"

RelationModel::RelationModel(QObject* pParent) : Model{pParent}{}

RelationModel::RelationModel(TableModel* pDestinationTableModel, TableModel* pSourceTableModel, const QString& sRelationship, QObject* pParent)
    : m_pDestinationTableModel{pDestinationTableModel}, m_pSourceTableModel{pSourceTableModel}, m_sRelationship{sRelationship}, Model{pParent}
{

}
int RelationModel::GetDestinationRowIdx()const
{
    return ms_iDestinationRowIdx;
}
int RelationModel::GetDestinationTableID()const
{
    return m_pDestinationTableModel->GetID();
}
int RelationModel::GetSourceRowIdx()const
{
    return m_iSourceRowIdx;
}
int RelationModel::GetSourceTableID()const
{
    return m_pSourceTableModel->GetID();
}
QString RelationModel::GetRelationship()const
{
    return m_sRelationship;
}
void RelationModel::SetDestinationTableModel(TableModel* pDestinationTableModel)
{
    if(m_pDestinationTableModel != pDestinationTableModel)
    {
        m_pDestinationTableModel = pDestinationTableModel;
        emit destinationTableIDChanged();
    }
} 
void RelationModel::SetSourceTableModel(TableModel* pSourceTableModel)
{
    if(m_pSourceTableModel != pSourceTableModel)
    {
        m_pSourceTableModel = pSourceTableModel;
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
    m_iSourceRowIdx = 0;
    const QString sSourceColumnName = m_pSourceTableModel->GetName() + "ID";
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