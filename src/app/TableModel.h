#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QObject>

class TableModel : public QObject{
    Q_OBJECT
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)

public:
    TableModel(const QString& sName, QObject *parent = nullptr);
    ~TableModel();
    
    QString GetName() const;
    void SetName(const QString &name);
signals:
    void nameChanged();
private:
    QString m_sName;
};

#endif // TABLEMODEL_H_