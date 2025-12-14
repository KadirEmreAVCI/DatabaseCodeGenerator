#include "RelationController.h"
#include "RelationModel.h"
#include <QDebug>

RelationController::RelationController(QObject *parent)
    : QObject{parent}
{

}
QList<QObject*> RelationController::GetRelations()const
{
    QList<QObject*> lsRelations;
    lsRelations.reserve(static_cast<int>(m_vecRelation.size()));
    for (auto pRelation : m_vecRelation) 
    {
        if (pRelation != nullptr) 
        {
            lsRelations.append(pRelation);
        } 
        else 
        {
            qDebug() << "Warning: null Relation Model";
        }
    }
    return lsRelations;
}
void RelationController::AddRelation(RelationModel* pRelationModel)
{
    if(nullptr != pRelationModel)
    {
        m_vecRelation.push_back(pRelationModel);
        emit relationsChanged();
    }
    else
    {
        qDebug() << "Error: RelationModel pointer is null.";
    }
}