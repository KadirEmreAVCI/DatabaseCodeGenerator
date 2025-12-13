#ifndef RELATIONMODEL_H_
#define RELATIONMODEL_H_

// Standard Headers
#include <memory>

// Project Headers
#include "Model.h"
#include "TableModel.h"

class RelationModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int destinationRowIdx READ GetDestinationRowIdx)
    Q_PROPERTY(int destinationTableID READ GetDestinationTableID NOTIFY destinationTableIDChanged)
    Q_PROPERTY(int sourceRowIdx READ GetSourceRowIdx NOTIFY sourceRowIdxChanged)
    Q_PROPERTY(int sourceTableIdx READ GetSourceTableID NOTIFY sourceTableIDChanged)
    Q_PROPERTY(QString relationship READ GetRelationship NOTIFY relationshipChanged)
public:
    explicit RelationModel(QObject* pParent = nullptr);
    RelationModel(TableModel* pDestinationTableModel, TableModel* pSourceTableModel, const QString& sRelationship, QObject* pParent = nullptr);

    // Getters
    int GetDestinationRowIdx()const;
    int GetDestinationTableID()const;
    int GetSourceRowIdx()const;
    int GetSourceTableID()const;
    QString GetRelationship()const;

    // Setters
    void SetDestinationTableModel(TableModel*);
    void SetSourceTableModel(TableModel*);
    void SetRelationship(const QString&);
private:
    void CalculateSourceRowIdx();

    const static int ms_iDestinationRowIdx{0};
    int m_iSourceRowIdx{-1};
    TableModel* m_pDestinationTableModel{nullptr};
    TableModel* m_pSourceTableModel{nullptr};
    QString m_sRelationship{""};
signals:
    void destinationTableIDChanged();
    void sourceRowIdxChanged();
    void sourceTableIDChanged();
    void relationshipChanged();
};

#endif // RELATIONMODEL_H_