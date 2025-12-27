#ifndef RELATIONCONTROLLER_H_
#define RELATIONCONTROLLER_H_

#include <QObject>
#include <QRectF>
#include <QList>
#include <memory>

class RelationModel;

class RelationController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> relations READ GetRelations NOTIFY relationsChanged)
public:
    static RelationController& GetInstance();
    RelationController(const RelationController&) = delete;
    RelationController& operator=(const RelationController&) = delete;
    ~RelationController() = default;

    // Getters
    QList<QObject*> GetRelations()const;

    void AddRelation(std::shared_ptr<RelationModel> spRelationModel);
public slots:
    void onTableDeleteRequested(int iTableID);
    void onNewRelationEstablished(int iSourceTableID, int iDestinationTableID);
    void onRelationshipChangeRequested(int iID, const QString& sRelationship);
    void onRelationshipDeleteRequested(int iID);
private:
    RelationController(QObject *parent = nullptr);
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    void UpdateSourceTableRowIndexes(int iSourceTableID);
    void HandleRelationBasedColumns(std::shared_ptr<const RelationModel> spRelation);
    std::map<int, std::shared_ptr<RelationModel>> m_mapspRelations; 
    int m_iNextRelationID = 0;
signals:
    void relationsChanged();
};

#endif // RELATIONCONTROLLER_H_