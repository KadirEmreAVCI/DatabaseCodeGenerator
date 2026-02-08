#ifndef COLUMNMODEL_H_
#define COLUMNMODEL_H_

#include "Model.h"

class ColumnModel : public Model{
    Q_OBJECT
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ GetType NOTIFY typeChanged)
    Q_PROPERTY(bool isEnabled READ GetIsEnabled NOTIFY isEnabledChanged)
    Q_PROPERTY(bool isPrimaryKey READ GetIsPrimaryKey NOTIFY isPrimaryKeyChanged)
    Q_PROPERTY(bool isForeignKey READ GetIsForeignKey NOTIFY isForeignKeyChanged)
public:
    ColumnModel(int iID, const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique, bool blIsForeignKey, int iRelationID = -1, QObject *parent = nullptr);
    virtual ~ColumnModel()override = default;

    // Getters
    QString GetName() const;
    QString GetType() const;
    bool GetIsEnabled() const;
    bool GetIsPrimaryKey() const;
    bool GetIsForeignKey() const;
    int GetRelationID()const;

    // Setters
    void SetName(const QString &name);
    void SetType(const QString& sType);
    void SetIsEnabled(bool blEnabled);
    void SetIsPrimaryKey(bool blPrimaryKey);
    void SetIsForeignKey(bool blForeignKey);
signals:
    void nameChanged();
    void typeChanged();
    void isEnabledChanged();
    void isPrimaryKeyChanged();
    void isForeignKeyChanged();
private:
    QString m_sName;
    QString m_sType;
    bool m_blIsEnabled{false};
    bool m_blIsPrimaryKey{false};
    bool m_blIsForeignKey{false};
    int m_iRelationID{-1};
};
#endif // COLUMNMODEL_H_