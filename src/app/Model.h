#ifndef MODEL_H_
#define MODEL_H_

#include <QObject>

struct Position{
    Position(int x = 0, int y = 0)
    {
        Position::x = x;
        Position::y = y;
    }
    int x;
    int y;
};

class Model : public QObject{
    Q_OBJECT
    Q_PROPERTY(int x READ GetX NOTIFY positionChanged)
    Q_PROPERTY(int y READ GetY NOTIFY positionChanged)
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
public:
    Model(const Position& rPosition = {}, const QString& sName = "", QObject *parent = nullptr);
    virtual ~Model() = default;
    
    QString GetName() const;
    int GetX() const;
    int GetY() const;
    
    void SetPosition(int x, int y);
    void SetName(const QString &name);
protected:
    Position m_rPosition;
    QString m_sName;
signals:
    void positionChanged();
    void nameChanged();
};

#endif // MODEL_H_