#ifndef COLUMNITEMMODEL_H_
#define COLUMNITEMMODEL_H_

#include "Model.h"

class ColumnItemModel : public Model{
    Q_OBJECT
    Q_PROPERTY(QString type READ GetType NOTIFY typeChanged)
public:
    ColumnItemModel(const QString& sType, const Position& rPosition = {}, const QString& sName = "", QObject *parent = nullptr);
    virtual ~ColumnItemModel()override = default;

    QString GetType() const;

    void SetType(const QString &type);
signals:
    void typeChanged();
private:
    QString m_sType;
};
#endif // COLUMNITEMMODEL_H_