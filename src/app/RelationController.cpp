#include "RelationController.h"
#include "RelationModel.h"
#include <QDebug>
#include <algorithm>

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