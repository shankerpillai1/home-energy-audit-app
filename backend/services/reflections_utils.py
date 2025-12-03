from sqlalchemy.inspection import inspect

def model_to_dict(model):
    """
    Convert any SQLAlchemy model to dict dynamically using reflection
    """
    return {
        column.key: getattr(model, column.key)
        for column in inspect(model).mapper.column_attrs
    }