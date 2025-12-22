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
    void OnTableDeleted(int iTableID);
    void onNewRelationEstablished(int iSourceTableID, int iDestinationTableID);
private:
    RelationController(QObject *parent = nullptr);
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    std::vector<std::unique_ptr<RelationModel>> m_vecupRelation; 
signals:
    void relationsChanged();
};

#endif // RELATIONCONTROLLER_H_