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

    void AddRelation(RelationModel*);
public slots:
    void onTableDeleteRequested(int iTableID);
    void onNewRelationEstablished(int iSourceTableID, int iDestinationTableID);
    void onRelationshipChangeRequested(int iID, const QString& sRelationship);
    void onRelationshipDeleteRequested(int iID);
private:
    RelationController(QObject *parent = nullptr);
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    void UpdateSourceTableRowIndexes(int iSourceTableID);
    void HandleRelationBasedColumns(const std::unique_ptr<RelationModel>& upRelation);
    std::map<int, std::unique_ptr<RelationModel>> m_mapupRelation; 
    int m_iNextRelationID = 0;
signals:
    void relationsChanged();
};

#endif // RELATIONCONTROLLER_H_