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
    void TableDeleted(int iTableID);
public slots:
    void onNewRelationEstablished(int iSourceTableID, int iDestinationTableID);
    void onRelationshipChangeRequested(int iID, const QString& sRelationship);
    void onRelationshipDeleteRequested(int iID);
private:
    RelationController(QObject *parent = nullptr);
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    void UpdateSourceTableRowIndexes(int iSourceTableID);
    std::vector<std::unique_ptr<RelationModel>> m_vecupRelation; 
    int m_iNextRelationID = 0;
signals:
    void relationsChanged();
};

#endif // RELATIONCONTROLLER_H_