#ifndef RELATIONCONTROLLER_H_
#define RELATIONCONTROLLER_H_

#include <QObject>
#include <QRectF>
#include <QList>

class RelationModel;

class RelationController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> relations READ GetRelations NOTIFY relationsChanged)
public:
    RelationController(QObject *parent = nullptr);
    ~RelationController() = default;

    // Getters
    QList<QObject*> GetRelations()const;

    void AddRelation(RelationModel*);
public slots:

private:
    std::vector<RelationModel*> m_vecRelation; 
signals:
    void relationsChanged();
};

#endif // RELATIONCONTROLLER_H_