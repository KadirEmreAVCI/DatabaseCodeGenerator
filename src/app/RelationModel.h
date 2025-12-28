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
    RelationModel(int iID, std::weak_ptr<const TableModel> wpDestinationTable, std::weak_ptr<const TableModel> wpSourceTable, const QString& sRelationship, QObject* pParent = nullptr);

    // Getters
    int GetID() const;
    std::weak_ptr<const TableModel> GetDestinationTable()const;
    std::weak_ptr<const TableModel> GetSourceTable()const;
    int GetDestinationRowIdx()const;
    int GetDestinationTableID()const;
    int GetSourceRowIdx()const;
    int GetSourceTableID()const;
    QString GetRelationship()const;

    // Setters
    void SetID(int);
    void SetDestinationTable(std::weak_ptr<const TableModel>);
    void SetSourceTable(std::weak_ptr<const TableModel>);
    void SetRelationship(const QString&);

    void Update();
private:
    void UpdateSourceRowIdx();

    int m_iID;
    const static int ms_iDestinationRowIdx{0};
    int m_iDestinationTableID{-1};
    int m_iSourceRowIdx{-1};
    int m_iSourceTableID{-1};
    std::weak_ptr<const TableModel> m_wpDestinationTable{};
    std::weak_ptr<const TableModel> m_wpSourceTable{};
    QString m_sRelationship{""};
signals:
    void idChanged();
    void destinationTableIDChanged();
    void sourceRowIdxChanged();
    void sourceTableIDChanged();
    void relationshipChanged();
};

#endif // RELATIONMODEL_H_