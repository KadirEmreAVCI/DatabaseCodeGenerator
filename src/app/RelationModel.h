#ifndef RELATIONMODEL_H_
#define RELATIONMODEL_H_

// Standard Headers
#include <memory>

// Project Headers
#include "Model.h"

class TableModel;

class RelationModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
    Q_PROPERTY(int destinationRowIdx READ GetDestinationRowIdx)
    Q_PROPERTY(int destinationTableID READ GetDestinationTableID NOTIFY destinationTableIDChanged)
    Q_PROPERTY(int sourceRowIdx READ GetSourceRowIdx NOTIFY sourceRowIdxChanged)
    Q_PROPERTY(int sourceTableID READ GetSourceTableID NOTIFY sourceTableIDChanged)
    Q_PROPERTY(QString relationship READ GetRelationship NOTIFY relationshipChanged)
public:
    explicit RelationModel(QObject* pParent = nullptr);
    RelationModel(int iID, TableModel* pDestinationTable, TableModel* pSourceTable, const QString& sRelationship, QObject* pParent = nullptr);
    virtual ~RelationModel() override = default;

    // Getters
    int GetID() const;
    TableModel* GetDestinationTable()const;
    TableModel* GetSourceTable()const;
    int GetDestinationRowIdx()const;
    int GetDestinationTableID()const;
    int GetSourceRowIdx()const;
    int GetSourceTableID()const;
    QString GetRelationship()const;
    QString GetRelationBasedColumnName()const;
    void DestinationTableRenamed()const;

    // Setters
    void SetID(int);
    void SetDestinationTable(TableModel*);
    void SetSourceTable(TableModel*);
    void SetRelationship(const QString&);

private:
    int m_iID;
    const static int ms_iDestinationRowIdx{0};
    TableModel* m_pDestinationTable{};
    TableModel* m_pSourceTable{};
    QString m_sRelationship{""};
signals:
    void idChanged();
    void destinationTableIDChanged();
    void sourceRowIdxChanged();
    void sourceTableIDChanged();
    void relationshipChanged();
};

#endif // RELATIONMODEL_H_