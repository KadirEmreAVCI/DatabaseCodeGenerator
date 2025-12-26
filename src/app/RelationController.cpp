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
        m_vecupRelation.emplace_back(pRelationModel);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
}
void RelationController::OnTableDeleted(int iTableID)
{    
    const size_t szErasedRelation = std::erase_if(m_vecupRelation, [iTableID](const auto& upRelation){
        return (upRelation == nullptr) || (upRelation->GetDestinationTableID() == iTableID) || (upRelation->GetSourceTableID() == iTableID);
    });
    if(szErasedRelation > 0)
    {
        emit relationsChanged();
    }
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
void RelationController::onRelationshipChangeRequested(int iSourceTableID, int iDestinationTableID, const QString& sRelationship)
{
    if(IsRelationExists(iSourceTableID, iDestinationTableID))
    {
        const auto iterRelation = std::find_if(m_vecupRelation.begin(), m_vecupRelation.end(), [iSourceTableID, iDestinationTableID](const auto& upRelation){
            if(upRelation != nullptr)
            {
                return (upRelation->GetSourceTableID() == iSourceTableID) && (upRelation->GetDestinationTableID() == iDestinationTableID);
            }
            return false;
        });
        if(iterRelation != m_vecupRelation.end())
        {
            (*iterRelation)->SetRelationship(sRelationship);
        }
    }
    else
    {
        qDebug() << "Warning: No existing relation between source table ID" << iSourceTableID << "and destination table ID" << iDestinationTableID;
    }
}
void RelationController::onRelationshipDeleteRequested(int iSourceTableID, int iDestinationTableID)
{
    const size_t szErasedRelation = std::erase_if(m_vecupRelation, [iSourceTableID, iDestinationTableID](const auto& upRelation){
        if(upRelation != nullptr)
        {
            return (upRelation->GetSourceTableID() == iSourceTableID) && (upRelation->GetDestinationTableID() == iDestinationTableID);
        }
        return false;
    });
    if(szErasedRelation > 0)
    {
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Warning: No existing relation to delete between source table ID" << iSourceTableID << "and destination table ID" << iDestinationTableID;
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