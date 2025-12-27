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
    lsRelations.reserve(static_cast<int>(m_mapupRelation.size()));
    for (const auto& [iID, upRelation] : m_mapupRelation) 
    {
        if (upRelation != nullptr) 
        {
            lsRelations.append(upRelation.get());
        } 
        else 
        {
            qDebug() << "Error: RelationModel pointer is null.";
        }
    }
    return lsRelations;
}
void RelationController::AddRelation(RelationModel* pRelationModel)
{
    if(nullptr != pRelationModel)
    {
        pRelationModel->SetID(m_iNextRelationID++);
        m_mapupRelation.emplace(pRelationModel->GetID(), std::unique_ptr<RelationModel>(pRelationModel));
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
}
void RelationController::onTableDeleteRequested(int iTableID)
{
    for(auto iterRelation = m_mapupRelation.begin(); iterRelation != m_mapupRelation.end();)
    {
        if(iterRelation->second != nullptr && (iterRelation->second->GetSourceTableID() == iTableID || iterRelation->second->GetDestinationTableID() == iTableID))
        {
            HandleRelationBasedColumns(iterRelation->second);
            iterRelation = m_mapupRelation.erase(iterRelation);
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
        AddRelation(new RelationModel(
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
    if(auto iterChangedRelation = m_mapupRelation.find(iID); iterChangedRelation != m_mapupRelation.end() && iterChangedRelation->second != nullptr)
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
    if(auto iterChangedRelation = m_mapupRelation.find(iID); iterChangedRelation != m_mapupRelation.end() && iterChangedRelation->second != nullptr)
    {
        HandleRelationBasedColumns(iterChangedRelation->second);
        m_mapupRelation.erase(iterChangedRelation);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Warning: No existing relation to delete with ID" << iID;
    }
}
bool RelationController::IsRelationExists(int iSourceTableID, int iDestinationTableID)const
{
    return std::any_of(m_mapupRelation.cbegin(), m_mapupRelation.cend(), [iSourceTableID, iDestinationTableID](const auto& upRelation){
        if(upRelation.second != nullptr)
        {
            return (upRelation.second->GetSourceTableID() == iSourceTableID) && (upRelation.second->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
void RelationController::UpdateSourceTableRowIndexes(int iSourceTableID)
{
    for(const auto& [iID, upRelation] : m_mapupRelation)
    {
        if(upRelation != nullptr && upRelation->GetSourceTableID() == iSourceTableID)
        {
            upRelation->UpdateSourceRowIdx();
        }
    }
}
void RelationController::HandleRelationBasedColumns(const std::unique_ptr<RelationModel>& upRelation)
{
    const int iSourceTableID = upRelation->GetSourceTableID();
    const int iDestinationTableID = upRelation->GetDestinationTableID();
    if(TableController::GetInstance().RelationshipDeleted(iSourceTableID, iDestinationTableID))
    {
        UpdateSourceTableRowIndexes(iSourceTableID);
    }
}