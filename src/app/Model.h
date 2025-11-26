#ifndef MODEL_H_
#define MODEL_H_

#include <QObject>

class Model : public QObject {
    Q_OBJECT
public:
    Model();
    virtual ~Model() = default; 
};

#endif // MODEL_H_