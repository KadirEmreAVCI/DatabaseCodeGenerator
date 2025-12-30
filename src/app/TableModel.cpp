#include "TableModel.h"
#include "ColumnListModel.h"
#include "ColumnModel.h"
#include "RelationModel.h"

TableModel::TableModel(int iID, const QString& sName, const QPointF& rPointF, qreal rWidth, qreal rHeight, QObject *parent) 
    : Model(parent), m_iID{iID}, m_sName{sName}, m_rPointF{rPointF}, m_rWidth{rWidth}, m_rHeight{rHeight}, m_upColumnListModel{std::make_unique<ColumnListModel>(this)}
{
}
void TableModel::AddColumn(std::shared_ptr<ColumnModel> spColumn)
{
    if (spColumn != nullptr && m_upColumnListModel != nullptr)
    {
        m_upColumnListModel->AddColumn(spColumn);
    }
}
int TableModel::GetID() const
{
    return m_iID;
}
QString TableModel::GetName() const
{
    return m_sName;
}
QPointF TableModel::GetPointF()const
{
    return m_rPointF;
}
qreal TableModel::GetWidth()const
{
    return m_rWidth;
}
qreal TableModel::GetHeight()const
{
    return m_rHeight;
}
ColumnListModel* TableModel::GetColumnListModel() const
{
    return m_upColumnListModel.get();
}
void TableModel::SetID(int iID)
{
    if(m_iID != iID)
    {
        m_iID = iID;
        emit idChanged();
    }
}
void TableModel::SetName(const QString &sName)
{
    if(m_sName != sName)
    {
        m_sName = sName;
        emit nameChanged();
        for(auto pIncomingRelation : m_vecIncomingRelations)
        {
            if(pIncomingRelation != nullptr)
            {
                pIncomingRelation->DestinationTableRenamed();
            }
        }
    }
}
void TableModel::SetPoint(const QPointF& rPointF)
{
    if(m_rPointF != rPointF)
    {
        m_rPointF = rPointF;
        emit pointChanged();
    }
}
void TableModel::SetWidth(qreal rWidth)
{
    m_rWidth = rWidth;
}
void TableModel::SetHeight(qreal rHeight)
{
    m_rHeight = rHeight;
}
void TableModel::Attach(const RelationModel* pRelation, RelationRole eRelationRole)
{
    if(pRelation != nullptr)
    {
        if(eRelationRole == RelationRole::eOutgoing)
        {
            AddRelationBasedColumn(pRelation->GetID(), pRelation->GetRelationBasedColumnName());
            m_vecOutgoingRelations.push_back(pRelation);
        }
        else if(eRelationRole == RelationRole::eIncoming)
        {
            m_vecIncomingRelations.push_back(pRelation);
        }
    }
}   
void TableModel::Detach(const RelationModel* pRelation, RelationRole eRelationRole)
{
    if(pRelation != nullptr)
    {
        if(eRelationRole == RelationRole::eOutgoing)
        {
            if(m_upColumnListModel->RemoveRelationBasedColumn(pRelation->GetID()))
            {
                std::erase(m_vecOutgoingRelations, pRelation);
            }
            else
            {
                qDebug() << "TableModel::Detach Relation based column could not be removed, relation ID: " << pRelation->GetID();
            }
        }
        else if(eRelationRole == RelationRole::eIncoming)
        {
            std::erase(m_vecIncomingRelations, pRelation);
        }
    }
}
void TableModel::AddRelationBasedColumn(int iRelationID, const QString& sRelationBasedColumnName)
{
    const QString sRelationColumnType = "INT"; 
    const bool blIsEnabled = false;
    const bool blIsPrimaryKey = false;
    const bool blIsRelationSource = true;

    auto spRelationColumn = std::make_shared<ColumnModel>(sRelationBasedColumnName, sRelationColumnType, blIsEnabled, blIsPrimaryKey, blIsRelationSource, iRelationID);
    m_upColumnListModel->AddRelationBasedColumn(spRelationColumn);
}
int TableModel::GetRelationBasedColumnIdx(int iRelationID)const
{
    return m_upColumnListModel->GetRelationBasedColumnIdx(iRelationID);
}
void TableModel::RenameRelationBasedColumnName(int iRelationID, const QString& sNewRelationBasedColumnName)
{
    m_upColumnListModel->RenameRelationBasedColumnName(iRelationID, sNewRelationBasedColumnName);
}