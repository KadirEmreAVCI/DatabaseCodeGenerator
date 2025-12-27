#include "RelationController.h"
#include "RelationModel.h"
#include "TableController.h"
#include <QDebug>
#include <algorithm>

RelationController& RelationController::GetInstance()
{
    static RelationController instance;
    return instance;
}
RelationController::RelationController(QObject *parent)
    : QObject{parent}
{

}
QList<QObject*> RelationController::GetRelations()const
{
    QList<QObject*> lsRelations;
    lsRelations.reserve(static_cast<int>(m_mapspRelations.size()));
    for (const auto& [iID, spRelation] : m_mapspRelations) 
    {
        if (spRelation != nullptr) 
        {
            lsRelations.append(spRelation.get());
        } 
        else 
        {
            qDebug() << "Error: RelationModel pointer is null.";
        }
    }
    return lsRelations;
}
void RelationController::AddRelation(std::shared_ptr<RelationModel> spRelationModel)
{
    if(nullptr != spRelationModel)
    {
        spRelationModel->SetID(m_iNextRelationID++);
        m_mapspRelations.emplace(spRelationModel->GetID(), std::shared_ptr<RelationModel>(spRelationModel));
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
}
void RelationController::onTableDeleteRequested(int iTableID)
{
    for(auto iterRelation = m_mapspRelations.begin(); iterRelation != m_mapspRelations.end();)
    {
        if(iterRelation->second != nullptr && (iterRelation->second->GetSourceTableID() == iTableID || iterRelation->second->GetDestinationTableID() == iTableID))
        {
            HandleRelationBasedColumns(iterRelation->second);
            iterRelation = m_mapspRelations.erase(iterRelation);
        }
        else
        {
            ++iterRelation;
        }
    }
    emit relationsChanged();
    TableController::GetInstance().TableDeleted(iTableID);
}
void RelationController::onNewRelationEstablished(int iSourceTableID, int iDestinationTableID)
{
    if(!IsRelationExists(iSourceTableID, iDestinationTableID))
    {
        TableController::GetInstance().NewRelationEstablished(iSourceTableID, iDestinationTableID);
        AddRelation(std::make_shared<RelationModel>(
            TableController::GetInstance().GetTable(iDestinationTableID),
            TableController::GetInstance().GetTable(iSourceTableID),
            "1..*"));
    }
    else
    {
        qDebug() << "Warning: Relation already exists between source table ID" << iSourceTableID << "and destination table ID" << iDestinationTableID;
    }
}
void RelationController::onRelationshipChangeRequested(int iID, const QString& sRelationship)
{
    if(auto iterChangedRelation = m_mapspRelations.find(iID); iterChangedRelation != m_mapspRelations.end() && iterChangedRelation->second != nullptr)
    {
        iterChangedRelation->second->SetRelationship(sRelationship);
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iID << "to change relationship.";
    }
}
void RelationController::onRelationshipDeleteRequested(int iID)
{
    if(auto iterChangedRelation = m_mapspRelations.find(iID); iterChangedRelation != m_mapspRelations.end() && iterChangedRelation->second != nullptr)
    {
        HandleRelationBasedColumns(iterChangedRelation->second);
        m_mapspRelations.erase(iterChangedRelation);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Warning: No existing relation to delete with ID" << iID;
    }
}
bool RelationController::IsRelationExists(int iSourceTableID, int iDestinationTableID)const
{
    return std::any_of(m_mapspRelations.cbegin(), m_mapspRelations.cend(), [iSourceTableID, iDestinationTableID](const auto& spRelation){
        if(spRelation.second != nullptr)
        {
            return (spRelation.second->GetSourceTableID() == iSourceTableID) && (spRelation.second->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
void RelationController::UpdateSourceTableRowIndexes(int iSourceTableID)
{
    for(const auto& [iID, spRelation] : m_mapspRelations)
    {
        if(spRelation != nullptr && spRelation->GetSourceTableID() == iSourceTableID)
        {
            spRelation->UpdateSourceRowIdx();
        }
    }
}
void RelationController::HandleRelationBasedColumns(const std::shared_ptr<RelationModel>& spRelation)
{
    const int iSourceTableID = spRelation->GetSourceTableID();
    const int iDestinationTableID = spRelation->GetDestinationTableID();
    if(TableController::GetInstance().RelationshipDeleted(iSourceTableID, iDestinationTableID))
    {
        UpdateSourceTableRowIndexes(iSourceTableID);
    }
}