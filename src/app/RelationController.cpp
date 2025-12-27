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
    lsRelations.reserve(static_cast<int>(m_vecupRelation.size()));
    for (const auto& upRelation : m_vecupRelation) 
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
        m_vecupRelation.emplace_back(pRelationModel);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
}
void RelationController::onTableDeleteRequested(int iTableID)
{
    for(auto iterRelation = m_vecupRelation.begin(); iterRelation != m_vecupRelation.end();)
    {
        if(*iterRelation != nullptr && ((*iterRelation)->GetSourceTableID() == iTableID || (*iterRelation)->GetDestinationTableID() == iTableID))
        {
            HandleRelationBasedColumns(*iterRelation);
            iterRelation = m_vecupRelation.erase(iterRelation);
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
    auto iterChangedRelation = std::find_if(m_vecupRelation.begin(), m_vecupRelation.end(), [iID](const auto& upRelation){
        if(upRelation != nullptr)
        {
            return upRelation->GetID() == iID;
        }
        return false;
    });
    if(iterChangedRelation != m_vecupRelation.end())
    {
        (*iterChangedRelation)->SetRelationship(sRelationship);
    }
    else
    {
        qDebug() << "Warning: No existing relation found with ID" << iID << "to change relationship.";
    }
}
void RelationController::onRelationshipDeleteRequested(int iID)
{
    auto iterDeletedRelation = std::find_if(m_vecupRelation.begin(), m_vecupRelation.end(), [iID](const auto& upRelation){
        if(upRelation != nullptr)
        {
            return upRelation->GetID() == iID;
        }
        return false;
    });
    if(iterDeletedRelation != m_vecupRelation.end())
    {
        HandleRelationBasedColumns(*iterDeletedRelation);
        m_vecupRelation.erase(iterDeletedRelation);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Warning: No existing relation to delete with ID" << iID;
    }
}
bool RelationController::IsRelationExists(int iSourceTableID, int iDestinationTableID)const
{
    return std::any_of(m_vecupRelation.cbegin(), m_vecupRelation.cend(), [iSourceTableID, iDestinationTableID](const auto& upRelation){
        if(upRelation != nullptr)
        {
            return (upRelation->GetSourceTableID() == iSourceTableID) && (upRelation->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
}
void RelationController::UpdateSourceTableRowIndexes(int iSourceTableID)
{
    for(const auto& upRelation : m_vecupRelation)
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