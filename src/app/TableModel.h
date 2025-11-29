#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include "Model.h"
#include "ColumnListModel.h"

struct Position{
    Position(int x = 0, int y = 0)
    {
        Position::x = x;
        Position::y = y;
    }
    int x;
    int y;
};

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(int x READ GetX NOTIFY positionChanged)
    Q_PROPERTY(int y READ GetY NOTIFY positionChanged)
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
public:
    TableModel(const QString& sName, const Position& rPosition = {}, QObject *parent = nullptr);
    virtual ~TableModel()override = default;

    // Getters
    int GetID() const;
    QString GetName() const;
    int GetX() const;
    int GetY() const;
    ColumnListModel* GetColumnListModel() const;

    // Setters
    void SetID(int);
    void SetName(const QString &name);
    void SetPosition(int x, int y);
    void SetColumnListModel(ColumnListModel* pColumnListModel);
private:
    int m_iID;
    QString m_sName;
    Position m_rPosition;
    ColumnListModel* m_pColumnListModel;
signals:
    void idChanged();
    void nameChanged();
    void positionChanged();
};

#endif // TABLEMODEL_H_