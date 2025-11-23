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
public:
    Model(const Position& rPosition = {}, QObject *parent = nullptr);
    virtual ~Model() = default;
    
    void ChangePosition(int x, int y);
    int GetX() const;
    int GetY() const;
protected:
    Position m_rPosition;
signals:
    void positionChanged();
};

#endif // MODEL_H_