#include "TableModel.h"
#include "ColumnListModel.h"
#include "ColumnModel.h"
#include "RelationModel.h"

int TableModel::ms_iNextRelationID{0};

TableModel::TableModel(QObject *parent, const QString& sName, const QPointF& rPointF, qreal rWidth, qreal rHeight) 
    : Model(parent), m_sName{sName}, m_rPointF{rPointF}, m_rWidth{rWidth}, m_rHeight{rHeight}, m_pColumnListModel{new ColumnListModel(this)}
{
}
TableModel::~TableModel()
{
    qDebug() << "TableModel destructor called for table:" << m_sName;
    delete m_pColumnListModel;
    m_pColumnListModel = nullptr;
}
void TableModel::AddColumn(std::shared_ptr<ColumnModel> spColumn)
{
    if (spColumn != nullptr && m_pColumnListModel != nullptr)
    {
        m_pColumnListModel->AddColumn(spColumn);
    }
}
bool TableModel::AddRelation(std::shared_ptr<TableModel> spSourceTable, std::shared_ptr<const TableModel> spDestinationTable)
{
    if (spDestinationTable != nullptr)
    {
        AddRelationBasedColumn(spDestinationTable->GetName());
        const int iNextRelationID = ms_iNextRelationID++;
        m_mapspRelations.emplace(iNextRelationID, std::make_shared<RelationModel>(  iNextRelationID, 
                                                                                    spDestinationTable, 
                                                                                    spSourceTable,
                                                                                    "1..*"));
        return true;
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
    return false;
}
bool TableModel::RemoveRelation(int iRelationID)
{
    bool blRelationRemoved = false;
    for(auto iterRelation = m_mapspRelations.begin(); iterRelation != m_mapspRelations.end(); ++iterRelation)
    {
        if(iterRelation->second != nullptr && iterRelation->second->GetID() == iRelationID)
        {
            if(!iterRelation->second->GetDestinationTable().expired())
            {
                if(DeleteRelationBasedColumn(iterRelation->second->GetDestinationTable().lock()->GetName()))
                {
                    iterRelation = m_mapspRelations.erase(iterRelation);
                    blRelationRemoved = true;
                    break;
                }
                else
                {
                    qDebug() << "TableModel::Failed to delete relation-based column.";
                }
            }
            else
            {
                qDebug() << "TableModel::Error: Destination Table pointer is null.";
            }
        }
    }
    if(blRelationRemoved)
    {
        UpdateRemainingRelations();
    }
    return blRelationRemoved;
}
void TableModel::TableDeleteRequested(int iDeletedTableID)
{
    for(auto iterRelation = m_mapspRelations.begin(); iterRelation != m_mapspRelations.end(); ++iterRelation)
    {
        if(iterRelation->second != nullptr && iterRelation->second->GetDestinationTableID() == iDeletedTableID)
        {
            if(RemoveRelation(iterRelation->second->GetID()))
            {
                break;
            }
        }
    }
}
std::map<int, std::shared_ptr<RelationModel>> TableModel::GetRelations() const
{
    return m_mapspRelations;
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
    return m_pColumnListModel;
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
void TableModel::AddRelationBasedColumn(const QString& sDestinationTableName)
{
    const QString sRelationColumnName = sDestinationTableName + "ID";
    const QString sRelationColumnType = "INT"; 
    const bool blIsEnabled = false;
    const bool blIsPrimaryKey = false;
    const bool blIsRelationSource = true;

    auto spRelationColumn = std::make_shared<ColumnModel>(sRelationColumnName, sRelationColumnType, blIsEnabled, blIsPrimaryKey, blIsRelationSource);
    m_pColumnListModel->AddRelationBasedColumn(spRelationColumn);
}
bool TableModel::DeleteRelationBasedColumn(const QString& sDestinationTableName)
{
    const QString sRelationColumnName = sDestinationTableName + "ID";
    return m_pColumnListModel->RemoveColumn(sRelationColumnName);
}
void TableModel::UpdateRemainingRelations()
{
    for(auto [iID, spRelation] : m_mapspRelations)
    {
        if(spRelation != nullptr)
        {
            spRelation->UpdateSourceRowIdx();
        }
    }
}