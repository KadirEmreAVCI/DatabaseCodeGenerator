#ifndef RELATIONMODEL_H_
#define RELATIONMODEL_H_

// Standard Headers
#include <memory>

// Project Headers
#include "Model.h"

class RelationModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int destinationRowIdx READ GetDestinationRowIdx NOTIFY destinationRowIdxChanged)
    Q_PROPERTY(int destinationTableID READ GetDestinationTableID NOTIFY destinationTableIDChanged)
    Q_PROPERTY(int sourceRowIdx READ GetSourceRowIdx NOTIFY sourceRowIdxChanged)
    Q_PROPERTY(QString relationship READ GetRelationship NOTIFY relationshipChanged)
public:
    explicit RelationModel(QObject* pParent = nullptr);
    RelationModel(int iDestinationTableID, int iSourceRowIdx, QString sRelationship, QObject* pParent = nullptr);
    
    // Getters
    int GetDestinationRowIdx()const;
    int GetDestinationTableID()const;
    int GetSourceRowIdx()const;
    QString GetRelationship()const;

    // Setters
    void SetDestinationTableID(int);
    void SetSourceRowIdx(int);
    void SetRelationship(const QString&);
private:
    const static int ms_iDestinationRowIdx{0};
    int m_iDestinationTableID{-1};
    int m_iSourceRowIdx{-1};
    QString m_sRelationship{""};
signals:
    void destinationRowIdxChanged();
    void destinationTableIDChanged();
    void sourceRowIdxChanged();
    void relationshipChanged();
};

#endif // RELATIONMODEL_H_