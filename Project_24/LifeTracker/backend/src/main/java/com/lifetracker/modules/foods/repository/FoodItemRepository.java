package com.lifetracker.modules.foods.repository;

import com.lifetracker.modules.foods.entity.FoodItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FoodItemRepository extends JpaRepository<FoodItem, Long> {
    @Query("""
            SELECT f FROM FoodItem f
            WHERE f.active = true
              AND (f.system = true OR f.ownerUserId = :userId)
            ORDER BY f.name ASC
            """)
    List<FoodItem> findAllVisible(@Param("userId") Long userId);

    @Query("""
            SELECT f FROM FoodItem f
            WHERE f.active = true
              AND (f.system = true OR f.ownerUserId = :userId)
              AND LOWER(f.name) LIKE LOWER(CONCAT('%', :query, '%'))
            ORDER BY f.name ASC
            """)
    List<FoodItem> searchVisible(@Param("userId") Long userId, @Param("query") String query);

    @Query("""
            SELECT f FROM FoodItem f
            WHERE f.id = :id
              AND f.active = true
              AND (f.system = true OR f.ownerUserId = :userId)
            """)
    Optional<FoodItem> findVisibleById(@Param("id") Long id, @Param("userId") Long userId);

    Optional<FoodItem> findByIdAndOwnerUserIdAndSystemFalseAndActiveTrue(Long id, Long ownerUserId);

    Optional<FoodItem> findByBarcode(String barcode);
}
